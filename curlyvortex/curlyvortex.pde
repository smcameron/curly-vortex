/*
 *      Copyright (C) 2014 Stephen M. Cameron
 *      Author: Stephen M. Cameron
 *
 *      This file is part of curly-vortex.
 *
 *      curly-vortex is free software; you can redistribute it and/or modify
 *      it under the terms of the GNU General Public License as published by
 *      the Free Software Foundation; either version 2 of the License, or
 *      (at your option) any later version.
 *
 *      curly-vortex is distributed in the hope that it will be useful,
 *      but WITHOUT ANY WARRANTY; without even the implied warranty of
 *      MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *      GNU General Public License for more details.
 *
 *      You should have received a copy of the GNU General Public License
 *      along with curly-vortex if not, write to the Free Software
 *      Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

/*
 * This work is based on the paper "Curl-Noise for Procedural Fluid Flow"
 * by Bridson, Hourihan, and Nordenstam.
 * 
 * See: https://www.cct.lsu.edu/~fharhad/ganbatte/siggraph2007/CD2/content/papers/046-bridson.pdf
 */

int xdim = 1400;
int ydim = 700;
int nparticles = 500000;
int framenumber = 0;
PImage source_color = loadImage("/home/scameron/test.jpg");

float[][] vx = new float[xdim][ydim];
float[][] vy = new float[xdim][ydim];
float[] px = new float[nparticles];
float[] py = new float[nparticles];
int pl[] = new int[nparticles];
color pc[] = new color[nparticles];

float c;

PImage img;

void setup()
{
	int cx, cy;

	size(xdim, ydim);
	frameRate(30);
	img = createImage(xdim, ydim, ARGB); 
	img.loadPixels();
	for (int j = 0; j < img.pixels.length; j++) {
		img.pixels[j] = color(0, 0, 0, 255);
	}
	img.updatePixels();

	for (int i = 0; i < nparticles; i++) {
		px[i] = random(xdim);
		py[i] = random(ydim);
		//pl[i] = int(random(nparticles / 100));
		pl[i] = 1000;
		if (source_color != null) {
			cx = int(float(source_color.width) * px[i] / float(xdim));
			cy = int(float(source_color.height) * py[i] / float(ydim));
			pc[i] = source_color.pixels[cy * source_color.width + cx]; 
		} else {
			pc[i] = color((px[i] / 5) % 100 + 100,
				255 - (px[i] + py[i] / 2) % 255,
				(500 - (px[i]) % 255) / 2, 40);
		}
	}
	c = 1.3;
}

void update_velocity_field()
{ 
	int x, y, r, g, b;
	float nxscale = 15;
	float nyscale = nxscale * float(ydim) / float(xdim);
	float amp = 30.0;
	float fx1, fy1, fx2, fy2, n1, n2, nx, ny, v, dx, dy;

	for (x = 0; x < xdim; x++) {
		for (y = 0; y < ydim; y++) {
			dx =  (random(100) * 0.005) - 0.25;
			dy =  (random(100) * 0.005) - 0.25;
			fx1 = ((float(x - 1) + dx) / float(xdim)) * nxscale;
			fy1 = ((float(y - 1) + dy) / float(ydim)) * nyscale;
			dx =  (random(100) * 0.005) - 0.25;
			dy =  (random(100) * 0.005) - 0.25;
			fx2 = ((float(x + 1) + dx) / float(xdim)) * nxscale;
			fy2 = ((float(y + 1) + dy) / float(ydim)) * nyscale;
			n1 = noise(fx1, fy1, c);
			n2 = noise(fx2, fy1, c);
			ny = -amp * (n2 - n1);
			n1 = noise(fx1, fy1, c);
			n2 = noise(fx1, fy2, c);
			nx = amp * (n2 - n1);
			vx[x][y] = nx;
			vy[x][y] = ny;
		}
	}
	c = c + 0.009;
} 

color heatmap(float val, float alpha, float multiplier)
{
	float r, g, b;

	b = 255.0 * (1.0 - val / 0.5) + 30;
	if (b < 0)
		b = 0;
	r = 255.0 * (val / 0.5 - 0.5) + 30;
	if (r < 0)
		r = 0;
	g = 255.0 - r / 2.5 - b / 2.5;
	return color(int(r * multiplier), int(g * multiplier), int(b * multiplier), alpha);
}


void draw()
{
	float ivx, ivy, v;
	int tx, ty;
	color clr;

	tx = 0;
	ty = 0;
	if ((framenumber % 20) == 0) {
		update_velocity_field();
	}
	for (int j = 0; j < img.pixels.length; j++) {
		ivx = vx[tx][ty];
		ivy = vy[tx][ty];
		v = sqrt(ivx * ivx + ivy * ivy);
		if (v > 6.0)
			v = 6.0;
		clr = heatmap(v / 2.0, 10, 0.0);
		//clr = color(5, 5, 5, 0.1);
		img.pixels[j] = clr;
		tx++;
		if (tx >= xdim) {
			tx = 0;
			ty++;
		}
	}
	img.updatePixels();
	for (int i = 0; i < nparticles; i++) {
		tx = int(px[i]);
		ty = int(py[i]);
		if (tx >= xdim)
			continue;
		if (ty >= ydim)
			continue;
		if (tx < 0)
			continue;
		if (ty < 0)
			continue;
		
		ivx = vx[tx][ty];
		ivy = vy[tx][ty];
		px[i] += ivx;
		py[i] += ivy;
/*
		v = sqrt(ivx * ivx + ivy * ivy);
		if (v > 6.0)
			v = 6.0;
		clr = heatmap(v / 2.0, 200, 0.9);
*/
		clr = pc[i];

		img.pixels[xdim * ty + tx] = clr;
		//pl[i]--;
		if (pl[i] <= 0) {
			px[i] = random(xdim);
			py[i] = random(ydim);
			//pl[i] = int(random(nparticles / 100));
			pl[i] = 100;
		}
	}
	img.updatePixels();
	image(img, 0, 0);
	framenumber++;
}

