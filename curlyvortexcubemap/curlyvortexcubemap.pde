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

 /*
  * This program runs six fake fluid dynamics sims on the six faces
  * of a cube initialized via a 3d perlin noise function.
  *
  * it produces skybox textures in six files named like this:
  * blah0.png
  * blah1.png
  * blah2.png
  * blah3.png
  * blah4.png
  * blah5.png
  *
  * and those images are laid out like this:
  *
  *  +------+
  *  |  4   |
  *  |      |
  *  +------+------+------+------+
  *  |  0   |  1   |  2   |  3   |
  *  |      |      |      |      |
  *  +------+------+------+------+
  *  |  5   |
  *  |      |
  *  +------+
  */


/* user adjustable parameters */
String source_image_file = "/home/scameron/test.jpg";
int xdim = 400;
int ydim = xdim;
int nparticles = 400000;
int framenumber = 0;
PImage source_color = loadImage(source_image_file);
float noise_scale = 1.0; /* xdim / 100 is not a bad default. */
float velocity_amplification = 30.0; /* xdim / 50 is not a bad default. */
int image_snapshot_period = 50;
int background_alpha = 3; /* between 0 and 255, needs to be a low number. */

float[][][] vx = new float[6][xdim][ydim];
float[][][] vy = new float[6][xdim][ydim];
float[] px = new float[nparticles];
float[] py = new float[nparticles];
int[] pf = new int[nparticles];
int pl[] = new int[nparticles];
color pc[] = new color[nparticles];

float c;

PImage[] img = new PImage[6];

int xo(int face)
{
	switch (face) {
	case 0: return 1;
	case 1: return 2;
	case 2: return 3;
	case 3: return 0;
	case 4: return 1;
	case 5: return 1;
	}
	return 0;
}

int yo(int face)
{
	switch (face) {
	case 0: return 1;
	case 1: return 1;
	case 2: return 1;
	case 3: return 1;
	case 4: return 0;
	case 5: return 2;
	}
	return 0;
}

void setup()
{
	int f;
	float cx, cy;

	size((int) (xdim * 4.1), (int) (ydim * 3.1));
	frameRate(30);
	for (f = 0; f < 6; f++) {
		img[f] = createImage(xdim, ydim, ARGB); 
		img[f].loadPixels();
		for (int j = 0; j < img[f].pixels.length; j++) {
			img[f].pixels[j] = color(0, 0, 0, 255);
		}
		img[f].updatePixels();

		for (int i = 0; i < nparticles; i++) {
			px[i] = random(xdim);
			py[i] = random(ydim);
			//pl[i] = int(random(nparticles / 100));
			pf[i] = int(random(6 * 1000)) % 6;
			pl[i] = 1000;
			if (source_color != null) {
				int picx, picy;
				cx = 0.25 * (float) source_color.width * px[i] / (float) xdim;
				cy = 0.333333 * (float) source_color.height * py[i] / (float) ydim ;
				picx = (int) ((float) source_color.width *
							(float) xo(pf[i]) * 0.25 + cx);
				picy = (int) ((float) source_color.height *
							(float) yo(pf[i]) / 3.0 + cy);
				pc[i] = source_color.pixels[picy * source_color.width + picx]; 
			} else {
				pc[i] = color((px[i] / 5) % 100 + 100,
					255 - (px[i] + py[i] / 2) % 255,
					(500 - (px[i]) % 255) / 2, 40);
			}
		}
	}
	c = 1.3;
}

void update_velocity_field(int face)
{ 
	int x, y, r, g, b;
	float amp = velocity_amplification;
	float fx1, fy1, fz1, fx2, fy2, fz2;
	float n1, n2, n3, nx, ny, nz, v, dx, dy, dz;
 /*  +---+
  *  | 4 |
  *  +---+---+---+---+
  *  | 0 | 1 | 2 | 3 |
  *  +---+---+---+---+
  *  | 5 |
  *  +---+  */
	for (x = 0; x < xdim; x++) {
		for (y = 0; y < ydim; y++) {
			dx = (random(100) * 0.005) - 0.25;
			dy = (random(100) * 0.005) - 0.25;
			dz = (random(100) * 0.005) - 0.25;
			switch (face) {
			case 0:
				fx1 = ((float(x - 1) + dx) / float(xdim)) * noise_scale;
				fy1 = ((float(y - 1) + dy) / float(ydim)) * noise_scale;
				fx2 = ((float(x + 1) + dx) / float(xdim)) * noise_scale;
				fy2 = ((float(y + 1) + dy) / float(ydim)) * noise_scale;
				n1 = noise(fx1, fy1, 0.0);
				n2 = noise(fx2, fy1, 0.0);
				ny = -amp * (n2 - n1);
				n1 = noise(fx1, fy1, 0.0);
				n2 = noise(fx1, fy2, 0.0);
				nx = amp * (n2 - n1);
				break;
			case 1:
				fx1 = ((float(x - 1) + dx) / float(xdim)) * noise_scale;
				fy1 = ((float(y - 1) + dy) / float(ydim)) * noise_scale;
				fx2 = ((float(x + 1) + dx) / float(xdim)) * noise_scale;
				fy2 = ((float(y + 1) + dy) / float(ydim)) * noise_scale;
				n1 = noise(noise_scale, fy1, fx1);
				n2 = noise(noise_scale, fy1, fx2);
				ny = -amp * (n2 - n1);
				n1 = noise(noise_scale, fy1, fx1);
				n2 = noise(noise_scale, fy2, fx1);
				nx = amp * (n2 - n1);
				break;
			case 2:
				fx1 = ((float(xdim - x + 1) + dx) / float(xdim)) * noise_scale;
				fy1 = ((float(y - 1) + dy) / float(ydim)) * noise_scale;
				fx2 = ((float(xdim - x - 1) + dx) / float(xdim)) * noise_scale;
				fy2 = ((float(y + 1) + dy) / float(ydim)) * noise_scale;
				n1 = noise(fx1, fy1, noise_scale);
				n2 = noise(fx2, fy1, noise_scale);
				ny = -amp * (n2 - n1);
				n1 = noise(fx1, fy1, noise_scale);
				n2 = noise(fx1, fy2, noise_scale);
				nx = amp * (n2 - n1);
				break;
			case 3:
				fx1 = ((float(xdim - x + 1) + dx) / float(xdim)) * noise_scale;
				fy1 = ((float(y - 1) + dy) / float(ydim)) * noise_scale;
				fx2 = ((float(xdim - x - 1) + dx) / float(xdim)) * noise_scale;
				fy2 = ((float(y + 1) + dy) / float(ydim)) * noise_scale;
				n1 = noise(0.0, fy1, fx1);
				n2 = noise(0.0, fy1, fx2);
				ny = -amp * (n2 - n1);
				n1 = noise(0.0, fy1, fx1);
				n2 = noise(0.0, fy2, fx1);
				nx = amp * (n2 - n1);
				break;
			case 4:
				fx1 = ((float(x - 1) + dx) / float(xdim)) * noise_scale;
				fy1 = ((float(ydim - y + 1) + dy) / float(ydim)) * noise_scale;
				fx2 = ((float(x + 1) + dx) / float(xdim)) * noise_scale;
				fy2 = ((float(ydim - y - 1) + dy) / float(ydim)) * noise_scale;
				n1 = noise(fx1, 0.0, fy1);
				n2 = noise(fx2, 0.0, fy1);
				ny = -amp * (n2 - n1);
				n1 = noise(fx1, 0.0, fy1);
				n2 = noise(fx1, 0.0, fy2);
				nx = amp * (n2 - n1);
				break;
			case 5:
				fx1 = ((float(x - 1) + dx) / float(xdim)) * noise_scale;
				fy1 = ((float(y - 1) + dy) / float(ydim)) * noise_scale;
				fx2 = ((float(x + 1) + dx) / float(xdim)) * noise_scale;
				fy2 = ((float(y + 1) + dy) / float(ydim)) * noise_scale;
				n1 = noise(fx1, noise_scale, fy1);
				n2 = noise(fx2, noise_scale, fy1);
				ny = -amp * (n2 - n1);
				n1 = noise(fx1, noise_scale, fy1);
				n2 = noise(fx1, noise_scale, fy2);
				nx = amp * (n2 - n1);
				break;
			default:
				nx = 0.0;
				ny = 0.0;
				break;
		  }
		  vx[face][x][y] = nx;
		  vy[face][x][y] = ny;
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

void move_particle(int i, float vx, float vy)
{
	float tx, ty, tmp;
	int nf, f;

	tx = px[i] + vx;
	ty = py[i] + vy;
	f = pf[i];
	if (tx < 0) {
		switch (f) {
		case 0: pf[i] = 3;
			tx += xdim;
			break;
		case 1: pf[i] = 0;
			tx += xdim;
			break;
		case 2: pf[i] = 1;
			tx += xdim;
			break;
		case 3: pf[i] = 2;
			tx += xdim;
			break;
		case 4: pf[i] = 3;
			tmp = tx;
			tx = ty;
			ty = -tmp;
			break;
		case 5: pf[i] = 3;
			tmp = tx;
			tx = ydim - ty;
			ty = xdim + tmp; 
			break;
		}
	} else {
		if (tx >= xdim) {
			switch (f) {
			case 0: pf[i] = 1;
				tx -= xdim;
				break;
			case 1: pf[i] = 2;
				tx -= xdim;
				break;
			case 2: pf[i] = 3;
				tx -= xdim;
				break;
			case 3: pf[i] = 0;
				tx -= xdim;
				break;
			case 4: pf[i] = 1;
				tmp = tx;
				tx = ydim - ty;
				ty = tmp - xdim;
				break;
			case 5: pf[i] = 1;
				tmp = tx;
				tx = ty;
				ty = ydim - (tmp - xdim);
				break;
			}
		}
	}

	f = pf[i];
	if (ty < 0) {
		switch (f) {
		case 0: pf[i] = 4; 
			ty = ydim + ty;  
			break;
		case 1: pf[i] = 4;
			tmp = tx;
			tx = xdim + ty; 
			ty = ydim - tmp;
			break;
		case 2: pf[i] = 4;
			tx = xdim - tx;
			ty = -ty;
			break;
		case 3: pf[i] = 4;
			tmp = tx;
			tx = -ty;
			ty = tmp;
			break;
		case 4: pf[i] = 2;
			tx = xdim - tx;
			ty = -ty;
			break;
		case 5:
			pf[i] = 0;
			ty = ydim + ty;
			break;
		}
	} else {
		if (ty >= ydim) {
			switch (f) {
			case 0: pf[i] = 5;
				ty = ty - ydim;
				break;
			case 1: pf[i] = 5;
				tmp = tx;
				tx = xdim - (ty - xdim); 
				ty = tmp; 
				break;
			case 2: pf[i] = 5;
				tx = xdim - tx;
				ty = ydim - (ty - ydim);
				break;
			case 3: pf[i] = 5;
				tmp = tx;
				tx = ty - ydim;
				ty = xdim - tmp;
				break;
			case 4: pf[i] = 0;
				ty = ydim - ty;
				break;
			case 5: pf[i] = 2;
				tx = xdim - tx;
				ty = ydim - (ty - ydim);
				break;
			}
		}
	}
	px[i] = tx;
	py[i] = ty;
}

void draw()
{
	float ivx, ivy, v;
	int tx, ty;
	color clr;

	if (framenumber == 0) {
		for (int f = 0; f < 6; f++) {
			update_velocity_field(f);
		}
	}
	for (int f = 0; f < 6; f++) {
		tx = 0;
		ty = 0;
		for (int j = 0; j < img[f].pixels.length; j++) {
			ivx = vx[f][tx][ty];
			ivy = vy[f][tx][ty];
			v = sqrt(ivx * ivx + ivy * ivy);
			if (v > 6.0)
				v = 6.0;
			clr = heatmap(v / 2.0, background_alpha, 0.0);
			//clr = color(5, 5, 5, 0.1);
			img[f].pixels[j] = clr;
			tx++;
			if (tx >= xdim) {
				tx = 0;
				ty++;
				if (ty >= ydim)
					break;
			}
		}
		img[f].updatePixels();
	}

	for (int i = 0; i < nparticles; i++) {
		int f = pf[i];

		tx = int(px[i]);
		ty = int(py[i]);

		if (tx >= xdim)
			tx = xdim - 1;	
		if (ty >= ydim)
			ty = ydim - 1;
		if (tx < 0)
			tx = 0;
		if (ty < 0)
			ty = 0;
	
		ivx = vx[f][tx][ty];
		ivy = vy[f][tx][ty];
		move_particle(i, ivx, ivy);
		clr = pc[i];

		img[f].pixels[xdim * ty + tx] = clr;
		//pl[i]--;
		if (pl[i] <= 0) {
			px[i] = random(xdim);
			py[i] = random(ydim);
			//pl[i] = int(random(nparticles / 100));
			pl[i] = 100;
		}
	}

	for (int f = 0; f < 6; f++) { 
		img[f].updatePixels();
		image(img[f], int(xdim * xo(f)), int(ydim * yo(f)));
	}
	if (image_snapshot_period != 0 &&
		(framenumber % image_snapshot_period) == 0) {
		save("image" + (10000 + framenumber) + ".png");
	}
	framenumber++;
}

